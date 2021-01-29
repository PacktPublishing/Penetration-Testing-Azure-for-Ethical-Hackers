FROM    node:9-alpine
ADD     https://raw.githubusercontent.com/PacktPublishing/Penetration-Testing-Azure-for-Ethical-Hackers/main/chapter-4/resources/package.json /
ADD     https://raw.githubusercontent.com/PacktPublishing/Penetration-Testing-Azure-for-Ethical-Hackers/main/chapter-4/resources/server.js /
ENV	APP_ID="$containerappid"
ENV	APP_KEY="$containerappsecret"
ENV	TENANT_ID="$tenantid"
RUN     npm install
EXPOSE  80
CMD     ["node", "server.js"]