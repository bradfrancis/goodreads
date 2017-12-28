from enum import Enum

class LogLevel(Enum):
    INFO = "INFO",
    WARNING = "WARNING",
    ERROR = "ERROR",
    FATAL = "FATAL"

    def __str__(self):
        return str(self.value[0])


def log(level, msg):
    print('{0}: {1}'.format(level, msg))