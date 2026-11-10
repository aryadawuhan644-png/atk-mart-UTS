<?php

namespace Tests\Feature;

use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class OnboardingPageTest extends TestCase
{
    public function test_homepage_renders_the_onboarding_inertia_page(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page->component('Onboarding', false));
    }
}
