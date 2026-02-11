import logging
import os
import re
import subprocess

import podman

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

LABEL_NAME = "fakmac.attacher.netif"


def main():
    """
    Listens to Podman events and waits for a container with a specific label.
    """
    # Get the Podman socket path from the environment or use a default
    socket_path = os.environ.get("PODMAN_SOCKET", "unix:///run/podman/podman.sock")

    try:
        client = podman.PodmanClient(base_url=socket_path)
    except Exception:
        logger.exception("Error connecting to Podman socket")
        return

    logger.info(f"Waiting for a new container with the label: {LABEL_NAME}")

    for event in client.events(decode=True):
        if event["Type"] == "container" and event["Action"] == "start":
            container_id = event["Actor"]["ID"]
            attributes = event["Actor"]["Attributes"]

            if LABEL_NAME in attributes:
                netif_regexp = attributes[LABEL_NAME]
                try:
                    container = client.containers.get(container_id)
                    pid = container.inspect().get("State", {}).get("Pid")
                    logger.info(
                        f"Found target container {container.name} with PID: {pid}"
                    )

                    netif = None
                    for interface in os.listdir("/sys/class/net"):
                        if re.match(netif_regexp, interface):
                            netif = interface
                            break

                    if netif is not None:
                        logger.info(
                            f"Attaching network interface '{netif}' to container '{container.name}'"
                        )
                        command = f"ip link set {netif} netns {pid}"
                        logger.info(f"Running command: {command}")
                        try:
                            subprocess.run(command, check=True, shell=True)
                            logger.info("Command executed successfully.")
                        except subprocess.CalledProcessError:
                            logger.exception("Command failed")
                        except FileNotFoundError:
                            logger.exception(f"Command not found: {command[0]}")
                    else:
                        logger.warning(
                            f"No network interface matching '{netif_regexp}' found."
                        )
                except podman.errors.NotFound:
                    logger.warning(
                        f"Could not find container {container_id[:12]}. It may have been removed."
                    )
                except Exception:
                    logger.exception("An error occurred while inspecting the container")


if __name__ == "__main__":
    main()
