document.addEventListener("DOMContentLoaded", function() {
    const userActions = document.querySelector(".user-actions");
    if (userActions) {
        const usuarioLogado = localStorage.getItem("usuarioLogado");
        if (usuarioLogado) {
            userActions.innerHTML = `
                <span style="margin-right: 15px; font-weight: 500;">Olá, ${usuarioLogado}</span>
                <a href="#" id="btnLogout" class="btn btn-outline">Sair</a>
            `;
            document.getElementById("btnLogout").addEventListener("click", function(e) {
                e.preventDefault();
                localStorage.removeItem("usuarioLogado");
                window.location.reload();
            });
        }
    }
});
