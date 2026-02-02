// ============================================
// NAVEGACIÓN ACTIVA
// ============================================
document.addEventListener('DOMContentLoaded', function() {
    const navLinks = document.querySelectorAll('.nav-link');
    const sections = document.querySelectorAll('section');

    // Actualizar enlace activo en navegación
    window.addEventListener('scroll', function() {
        let current = '';
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            
            if (scrollY >= (sectionTop - 100)) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href').slice(1) === current) {
                link.classList.add('active');
            }
        });
    });

    // Scroll suave en enlaces internos
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href.startsWith('#')) {
                e.preventDefault();
                const target = document.querySelector(href);
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth' });
                    // Actualizar URL sin recargar
                    window.history.pushState(null, null, href);
                }
            }
        });
    });
});

// ============================================
// FORMULARIO DE CONTACTO
// ============================================
document.addEventListener('DOMContentLoaded', function() {
    const contactForm = document.querySelector('.contact-form');
    
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            // Validación básica
            const nameInput = this.querySelector('input[name="name"]');
            const emailInput = this.querySelector('input[name="email"]');
            const messageInput = this.querySelector('textarea[name="message"]');
            
            if (!nameInput.value.trim()) {
                e.preventDefault();
                alert('Por favor ingresa tu nombre');
                return;
            }
            
            if (!emailInput.value.includes('@')) {
                e.preventDefault();
                alert('Por favor ingresa un email válido');
                return;
            }
            
            if (!messageInput.value.trim()) {
                e.preventDefault();
                alert('Por favor escribe un mensaje');
                return;
            }
            
            // Si usa Formspree, permitir submit normal
            // Si necesitas custom handling, agrega aquí
        });
    }
});

// ============================================
// ANIMACIÓN DE ENTRADA (Fade-in)
// ============================================
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

document.addEventListener('DOMContentLoaded', function() {
    const cards = document.querySelectorAll('.feature-card, .security-item, .tech-item');
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
});

// ============================================
// CONTROL DE HEADER AL HACER SCROLL
// ============================================
document.addEventListener('DOMContentLoaded', function() {
    const header = document.querySelector('.header');
    let lastScrollTop = 0;

    window.addEventListener('scroll', function() {
        const scrollTop = window.scrollY;
        
        // Agregar sombra cuando el usuario hace scroll
        if (scrollTop > 10) {
            header.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.12)';
        } else {
            header.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.08)';
        }
        
        lastScrollTop = scrollTop;
    });
});

// ============================================
// LOGGER (Para debugging)
// ============================================
console.log('%cFinanSecure Web', 'font-size: 24px; color: #0066cc; font-weight: bold;');
console.log('%cGestión Financiera Moderna y Segura', 'font-size: 14px; color: #2c3e50;');
console.log('%cTecnologías: Angular + ASP.NET Core 8.0 + PostgreSQL', 'font-size: 12px; color: #7f8c8d;');
