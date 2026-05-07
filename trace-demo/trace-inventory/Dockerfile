FROM docker.m.daocloud.io/eclipse-temurin:17-alpine AS jre-build
RUN $JAVA_HOME/bin/jlink \
         --add-modules java.base,java.logging,java.xml,java.naming,java.management,java.sql,java.security.jgss,java.net.http,java.desktop \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /javaruntime

FROM docker.m.daocloud.io/alpine:3.19
ENV PATH="${PATH}:/opt/java/bin"
COPY --from=jre-build /javaruntime /opt/java

# ⚠️ 注意这里的路径：由于是在模块目录下构建，直接填 target 即可
COPY target/trace-inventory-*.jar /app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "-Dfile.encoding=UTF-8", "/app.jar"]
