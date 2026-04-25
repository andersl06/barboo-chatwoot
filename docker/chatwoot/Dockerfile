ARG CHATWOOT_TAG=latest
FROM chatwoot/chatwoot:${CHATWOOT_TAG}

# Minimal wrapper to enforce safety checks before calling
# Chatwoot's official entrypoint.
COPY docker/chatwoot/entrypoints/chatwoot-entrypoint.sh /usr/local/bin/chatwoot-entrypoint.sh
RUN chmod 0755 /usr/local/bin/chatwoot-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/chatwoot-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
