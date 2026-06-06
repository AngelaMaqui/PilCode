document.addEventListener('DOMContentLoaded', () => {
    const wrapper = document.querySelector('.login-v2__wrapper');
    const page = document.querySelector('.login-v2');

    if (page && wrapper) {
        page.addEventListener('mousemove', (e) => {
            const x = (e.clientX / window.innerWidth - 0.5) * 12;
            const y = (e.clientY / window.innerHeight - 0.5) * 12;
            wrapper.style.transform = `translate(${x}px, ${y}px)`;
        });
        page.addEventListener('mouseleave', () => {
            wrapper.style.transform = '';
        });
    }

    const togglePwd = document.getElementById('toggle-password');
    const passwordInput = document.getElementById('password');

    togglePwd?.addEventListener('click', () => {
        const visible = passwordInput.type === 'text';
        passwordInput.type = visible ? 'password' : 'text';
        togglePwd.classList.toggle('visible', !visible);
        togglePwd.setAttribute('aria-label', visible ? 'Mostrar contraseña' : 'Ocultar contraseña');
        togglePwd.setAttribute('title', visible ? 'Mostrar contraseña' : 'Ocultar contraseña');
    });

    const form = document.getElementById('login-form');
    const submitBtn = document.getElementById('login-submit');

    form?.addEventListener('submit', () => {
        submitBtn?.classList.add('loading');
    });

    document.querySelectorAll('.login-v2__input').forEach(input => {
        input.addEventListener('focus', () => {
            input.closest('.login-v2__input-wrap')?.classList.add('focused');
        });
        input.addEventListener('blur', () => {
            input.closest('.login-v2__input-wrap')?.classList.remove('focused');
        });
    });
});
