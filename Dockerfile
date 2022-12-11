FROM python:3.10 AS build

LABEL org.label-schema.name="tclscanner" \
      org.label-schema.description="wrapper for tclscan" \
      org.label-schema.vcs-url="https://github.com/simonkowallik/tclscanner" \
      org.label-schema.vendor="Simon Kowallik"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/:/root/.cargo/bin:$PATH"

WORKDIR /build

COPY files/57E7C6324F81391D.asc /build/57E7C6324F81391D.asc

RUN echo "* install packages" \
&&  apt-get update -y \
&&  apt install -y \
          clang \
          curl \
          git \
          jq \
          less \
          make \
          tzdata \
          vim \
           \
&& echo "* remove default rust + tcl install" \
&&  apt-get remove -y \
          cargo \
          rustc \
          tcl8.6 \
&& apt-get autoremove -y

RUN echo "* download, compile, then install tcl" \
&&  cd /build \
&& curl -sSf -LO http://archive.ubuntu.com/ubuntu/pool/universe/t/tcl8.4/tcl8.4_8.4.20-8.dsc \
&& curl -sSf -LO http://archive.ubuntu.com/ubuntu/pool/universe/t/tcl8.4/tcl8.4_8.4.20.orig.tar.gz \
&& gpg --import 57E7C6324F81391D.asc \
&& gpg --verify tcl8.4_8.4.20-8.dsc \
&& grep "$(sha256sum tcl8.4_8.4.20.orig.tar.gz | cut -d' ' -f1)" tcl8.4_8.4.20-8.dsc > /dev/null \
&& echo "* tcl8.4 verified successfully" \
&& tar xzf tcl8.4_8.4.20.orig.tar.gz \
&&  cd /build/tcl8.4.20/unix \
&&  ./configure --enable-64bit --prefix=/usr \
&&  make install \
&&  make \
&&  ./configure --enable-64bit --prefix=/build/target \
&&  make install \
;

RUN echo "* install rust nightly" \
&&  curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly-2022-12-06 \
&&  rustup component add rustfmt;

RUN echo "* compile tclscan" \
&&  git clone https://github.com/simonkowallik/tclscan \
&&  cd tclscan \
&&  cargo install --path . \
&&  cp -f /build/tclscan/target/release/tclscan /build/target/bin/tclscan

FROM python:3.10-slim-bullseye AS tclscanner-image

LABEL org.label-schema.name="tclscanner" \
      org.label-schema.description="wrapper for tclscan" \
      org.label-schema.vcs-url="https://github.com/simonkowallik/tclscanner" \
      org.label-schema.vendor="Simon Kowallik"

VOLUME /scandir

WORKDIR /scandir

COPY --from=build /build/target /usr
COPY --from=build /build/tclscan/LICENSE /LICENSE.tclscan
COPY /LICENSE /LICENSE
COPY /README.md /README.md
COPY /tests/tcl/* /scandir

COPY files/tclscanner.py /usr/bin/tclscanner.py
RUN ln -s /usr/bin/tclscanner.py /usr/bin/tclscanner

CMD ["/usr/bin/tclscanner.py"]
