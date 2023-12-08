FROM fedora:latest

RUN sudo dnf makecache --refresh
RUN sudo dnf -y install curl tini

CMD ["sleep", "infinity"]
ENTRYPOINT ["tini", "--"]
