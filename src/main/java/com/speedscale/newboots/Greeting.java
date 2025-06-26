package com.speedscale.newboots;

/**
 * A simple greeting class that holds an ID and content.
 * This class is not designed for extension.
 */
public final class Greeting {
    /** The greeting ID. */
    private final long id;
    /** The greeting content. */
    private final String content;

    /**
     * Constructs a new Greeting with the specified ID and content.
     *
     * @param greetingId the greeting ID
     * @param greetingContent the greeting content
     */
    public Greeting(final long greetingId, final String greetingContent) {
        this.id = greetingId;
        this.content = greetingContent;
    }

    /**
     * Gets the greeting ID.
     *
     * @return the greeting ID
     */
    public long getId() {
        return id;
    }

    /**
     * Gets the greeting content.
     *
     * @return the greeting content
     */
    public String getContent() {
        return content;
    }
}
