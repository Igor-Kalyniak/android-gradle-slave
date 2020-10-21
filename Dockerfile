FROM epamedp/edp-jenkins-base-agent:1.0.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV GRADLE_VERSION=6.1.1 \
    ANDROID_SDK_VERSION=6609375 \
    ANDROID_SDK_ROOT=/opt/android-sdk \ 
    RUBY_VERSION=2.5.1

USER root

# Install Gradle
RUN curl -skL -o /tmp/gradle-bin.zip https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip && \
    mkdir -p /opt/gradle && \
    unzip -q /tmp/gradle-bin.zip -d /opt/gradle && \
    ln -sf /opt/gradle/gradle-$GRADLE_VERSION/bin/gradle /usr/local/bin/gradle

RUN yum install java-11-openjdk-devel.x86_64 -y && \
    rpm -V java-11-openjdk-devel.x86_64 && \
    yum clean all -y

# download and install Android SDK
# https://developer.android.com/studio#command-tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    chmod 775 ${ANDROID_SDK_ROOT} && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    unzip *tools*linux*.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    rm *tools*linux*.zip

ADD license_accepter.sh /opt/
RUN chmod +x /opt/license_accepter.sh && /opt/license_accepter.sh $ANDROID_SDK_ROOT

ENV PATH ${PATH}:/opt/gradle/bin:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator
ENV LD_LIBRARY_PATH ${ANDROID_SDK_ROOT}/emulator/lib64:${ANDROID_SDK_ROOT}/emulator/lib64/qt/lib
# WORKAROUND: for issue https://issuetracker.google.com/issues/37137213
ENV LD_LIBRARY_PATH ${ANDROID_SDK_ROOT}/emulator/lib64:${ANDROID_SDK_ROOT}/emulator/lib64/qt/lib
# patch emulator issue: Running as root without --no-sandbox is not supported. See https://crbug.com/638180.
# https://doc.qt.io/qt-5/qtwebengine-platform-notes.html#sandboxing-support
ENV QTWEBENGINE_DISABLE_SANDBOX 1

# Install Ruby packages
RUN yum install -y \
    zlib.i686 \
    ncurses-libs.i686 \
    bzip2-libs.i686 \
    rubygems \
    gcc-c++ \
    make \
    yum groupinstall -y "Development Tools" && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN wget https://rvm.io/binaries/centos/7/x86_64/ruby-${RUBY_VERSION}.tar.bz2 && \
    bunzip2 -dk ruby-${RUBY_VERSION}.tar.bz2 && \
    tar -xvpf ruby-${RUBY_VERSION}.tar && \
    (cd ruby-${RUBY_VERSION}; cp -R * /usr/local) && \
    gem install fastlane --no-document && \
    chmod 775 /usr/local/lib/ruby/gems/* && \
    rm -rf ruby-${RUBY_VERSION}.tar.bz2 ruby-${RUBY_VERSION}.tar ruby-${RUBY_VERSION}

WORKDIR $HOME/.gradle

RUN chown -R "1001:0" "$HOME" && \
    chown -R "1001:0" "/usr/local/lib/ruby/gems/2.5.0" && \
    chmod -R "g+rw" "$HOME"

USER 1001

USER 1001
