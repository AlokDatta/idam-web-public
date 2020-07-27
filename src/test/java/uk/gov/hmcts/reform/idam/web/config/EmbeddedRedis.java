package uk.gov.hmcts.reform.idam.web.config;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.redis.core.StringRedisTemplate;

@TestConfiguration
public class EmbeddedRedis {

    @MockBean
    private StringRedisTemplate template;
}
