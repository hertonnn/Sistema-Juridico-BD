import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.io.OutputStream;
import java.io.File;
import java.nio.file.Files;
import java.net.InetSocketAddress;
import java.sql.Connection;
import java.util.HashSet;

public class ServidorWeb {

    public static void iniciar(Connection con) {
        try {
            HttpServer server = HttpServer.create(new InetSocketAddress(8081), 0);
            
            // Endpoint para servir arquivos estáticos (HTML, CSS, JS, etc)
            server.createContext("/", new StaticFileHandler());
            
            // Endpoint para a API de Processos
            server.createContext("/api/processos", new ProcessosApiHandler(con));
            
            // Endpoint para detalhes de um Processo
            server.createContext("/api/processo", new ProcessoDetalheApiHandler(con));
            
            // Endpoints para Advogados e Leis
            server.createContext("/api/advogados", new AdvogadosApiHandler(con));
            server.createContext("/api/leis", new LeisApiHandler(con));
            server.createContext("/api/advogado", new AdvogadoDetalheApiHandler(con));
            server.createContext("/api/lei", new LeiDetalheApiHandler(con));
            
            // Endpoints para Login e Cadastro
            server.createContext("/api/cadastro", new CadastroApiHandler(con));
            server.createContext("/api/login", new LoginApiHandler(con));

            
            server.setExecutor(null);
            server.start();
            System.out.println("Servidor Web rodando em http://localhost:8081/");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    static class StaticFileHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String path = exchange.getRequestURI().getPath();
            if (path.equals("/")) {
                path = "/index.html";
            }
            
            File file = new File("src/view" + path);
            if (file.exists() && !file.isDirectory()) {
                if(path.endsWith(".css")) {
                    exchange.getResponseHeaders().set("Content-Type", "text/css");
                } else if(path.endsWith(".html")) {
                    exchange.getResponseHeaders().set("Content-Type", "text/html; charset=UTF-8");
                } else if(path.endsWith(".svg")) {
                    exchange.getResponseHeaders().set("Content-Type", "image/svg+xml");
                }
                
                exchange.sendResponseHeaders(200, file.length());
                OutputStream os = exchange.getResponseBody();
                Files.copy(file.toPath(), os);
                os.close();
            } else {
                String response = "404 Not Found";
                exchange.sendResponseHeaders(404, response.length());
                OutputStream os = exchange.getResponseBody();
                os.write(response.getBytes());
                os.close();
            }
        }
    }
    
    static class ProcessosApiHandler implements HttpHandler {
        private Connection con;
        
        public ProcessosApiHandler(Connection con) {
            this.con = con;
        }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("GET".equals(exchange.getRequestMethod())) {
                try {
                    HashSet<ProcessoBean> processos = ProcessoModel.listAll(con);
                    StringBuilder json = new StringBuilder();
                    json.append("[");
                    boolean first = true;
                    for (ProcessoBean p : processos) {
                        if (!first) json.append(",");
                        json.append("{");
                        json.append("\"id\":").append(p.getIdProcesso()).append(",");
                        json.append("\"numero\":\"").append(p.getNumeroProcesso() != null ? p.getNumeroProcesso() : "").append("\",");
                        json.append("\"tipo\":\"").append(p.getTipoProcesso() != null ? p.getTipoProcesso() : "").append("\",");
                        json.append("\"assunto\":\"").append(p.getAssunto() != null ? p.getAssunto() : "").append("\",");
                        json.append("\"status\":\"").append(p.getStatus() != null ? p.getStatus() : "").append("\",");
                        json.append("\"fk_id_vara\":").append(p.getFkIdVara());
                        json.append("}");
                        first = false;
                    }
                    json.append("]");
                    
                    byte[] response = json.toString().getBytes("UTF-8");
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, response.length);
                    OutputStream os = exchange.getResponseBody();
                    os.write(response);
                    os.close();
                } catch (Exception e) {
                    e.printStackTrace();
                    String response = "Erro no servidor ao buscar processos";
                    exchange.sendResponseHeaders(500, response.length());
                    OutputStream os = exchange.getResponseBody();
                    os.write(response.getBytes());
                    os.close();
                }
            } else {
                exchange.sendResponseHeaders(405, -1); // Method Not Allowed
            }
        }
    }

    static class ProcessoDetalheApiHandler implements HttpHandler {
        private Connection con;
        
        public ProcessoDetalheApiHandler(Connection con) {
            this.con = con;
        }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("GET".equals(exchange.getRequestMethod())) {
                try {
                    String query = exchange.getRequestURI().getQuery();
                    int id = -1;
                    if (query != null && query.contains("id=")) {
                        String[] parts = query.split("id=");
                        if(parts.length > 1) {
                            id = Integer.parseInt(parts[1].split("&")[0]);
                        }
                    }
                    if (id == -1) {
                        exchange.sendResponseHeaders(400, -1);
                        return;
                    }
                    
                    StringBuilder json = new StringBuilder("{");
                    
                    java.sql.PreparedStatement stProc = con.prepareStatement("SELECT * FROM Processo WHERE id_processo = ?");
                    stProc.setInt(1, id);
                    java.sql.ResultSet rsProc = stProc.executeQuery();
                    if (!rsProc.next()) {
                        exchange.sendResponseHeaders(404, -1);
                        return;
                    }
                    json.append("\"id\":").append(rsProc.getInt("id_processo")).append(",");
                    json.append("\"numero\":\"").append(rsProc.getString("numero_processo")).append("\",");
                    json.append("\"tipo\":\"").append(rsProc.getString("tipo_processo")).append("\",");
                    json.append("\"assunto\":\"").append(rsProc.getString("assunto")).append("\",");
                    json.append("\"status\":\"").append(rsProc.getString("status")).append("\",");
                    json.append("\"data_inicio\":\"").append(rsProc.getDate("data_inicio")).append("\",");
                    int idVara = rsProc.getInt("fk_id_vara");
                    rsProc.close();
                    stProc.close();
                    
                    java.sql.PreparedStatement stVara = con.prepareStatement("SELECT nome FROM Vara WHERE id_vara = ?");
                    stVara.setInt(1, idVara);
                    java.sql.ResultSet rsVara = stVara.executeQuery();
                    String varaNome = rsVara.next() ? rsVara.getString("nome") : "Desconhecida";
                    json.append("\"vara\":\"").append(varaNome).append("\",");
                    rsVara.close(); stVara.close();
                    
                    java.sql.PreparedStatement stPartes = con.prepareStatement("SELECT p.primeiro_nome, p.ultimo_nome, pa.parte_tipo FROM Parte pa JOIN Pessoa p ON pa.fk_id_pessoa = p.id_pessoa WHERE pa.fk_id_processo = ?");
                    stPartes.setInt(1, id);
                    java.sql.ResultSet rsPartes = stPartes.executeQuery();
                    json.append("\"partes\":[");
                    boolean firstParte = true;
                    while(rsPartes.next()) {
                        if(!firstParte) json.append(",");
                        String nomeCompleto = rsPartes.getString("primeiro_nome");
                        String ultimo = rsPartes.getString("ultimo_nome");
                        if (ultimo != null && !ultimo.trim().isEmpty()) {
                            nomeCompleto += " " + ultimo;
                        }
                        json.append("{\"nome\":\"").append(nomeCompleto).append("\",");
                        json.append("\"tipo\":\"").append(rsPartes.getString("parte_tipo")).append("\"}");
                        firstParte = false;
                    }
                    json.append("],");
                    rsPartes.close(); stPartes.close();
                    
                    java.sql.PreparedStatement stTram = con.prepareStatement("SELECT data_hora, tipo, descricao FROM Tramite WHERE fk_id_processo = ? ORDER BY data_hora DESC");
                    stTram.setInt(1, id);
                    java.sql.ResultSet rsTram = stTram.executeQuery();
                    json.append("\"tramites\":[");
                    boolean firstTram = true;
                    while(rsTram.next()) {
                        if(!firstTram) json.append(",");
                        json.append("{");
                        json.append("\"data\":\"").append(rsTram.getTimestamp("data_hora").toString().split("\\.")[0]).append("\",");
                        json.append("\"tipo\":\"").append(rsTram.getString("tipo")).append("\",");
                        String desc = rsTram.getString("descricao");
                        if(desc != null) desc = desc.replace("\"", "\\\"");
                        json.append("\"descricao\":\"").append(desc).append("\"");
                        json.append("}");
                        firstTram = false;
                    }
                    json.append("]");
                    rsTram.close(); stTram.close();
                    
                    json.append("}");
                    
                    byte[] response = json.toString().getBytes("UTF-8");
                    exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                    exchange.sendResponseHeaders(200, response.length);
                    OutputStream os = exchange.getResponseBody();
                    os.write(response);
                    os.close();
                } catch (Exception e) {
                    e.printStackTrace();
                    String response = "Erro interno";
                    exchange.sendResponseHeaders(500, response.length());
                    OutputStream os = exchange.getResponseBody();
                    os.write(response.getBytes());
                    os.close();
                }
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        }
    }

    static class AdvogadosApiHandler implements HttpHandler {
        private Connection con;
        public AdvogadosApiHandler(Connection con) { this.con = con; }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            try {
                java.sql.Statement st = con.createStatement();
                java.sql.ResultSet rs = st.executeQuery("SELECT a.fk_id_pessoa, p.primeiro_nome, p.ultimo_nome, a.oab, a.area_atuacao FROM Advogado a JOIN Pessoa p ON a.fk_id_pessoa = p.id_pessoa");
                StringBuilder json = new StringBuilder("[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(",");
                    json.append("{");
                    json.append("\"id\":").append(rs.getInt("fk_id_pessoa")).append(",");
                    String nome = rs.getString("primeiro_nome");
                    String ultimo = rs.getString("ultimo_nome");
                    if(ultimo != null && !ultimo.isEmpty()) nome += " " + ultimo;
                    json.append("\"nome\":\"").append(nome).append("\",");
                    json.append("\"oab\":\"").append(rs.getString("oab")).append("\",");
                    json.append("\"area\":\"").append(rs.getString("area_atuacao")).append("\"");
                    json.append("}");
                    first = false;
                }
                json.append("]");
                rs.close(); st.close();
                
                byte[] response = json.toString().getBytes("UTF-8");
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, response.length);
                OutputStream os = exchange.getResponseBody();
                os.write(response);
                os.close();
            } catch(Exception e) {
                exchange.sendResponseHeaders(500, -1);
            }
        }
    }

    static class LeisApiHandler implements HttpHandler {
        private Connection con;
        public LeisApiHandler(Connection con) { this.con = con; }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            try {
                java.sql.Statement st = con.createStatement();
                java.sql.ResultSet rs = st.executeQuery("SELECT * FROM Lei");
                StringBuilder json = new StringBuilder("[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(",");
                    json.append("{");
                    json.append("\"id\":").append(rs.getInt("id_lei")).append(",");
                    json.append("\"titulo\":\"").append(rs.getString("titulo")).append("\",");
                    json.append("\"detalhe\":\"").append(rs.getString("descricao")).append("\"");
                    json.append("}");
                    first = false;
                }
                json.append("]");
                rs.close(); st.close();
                
                byte[] response = json.toString().getBytes("UTF-8");
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, response.length);
                OutputStream os = exchange.getResponseBody();
                os.write(response);
                os.close();
            } catch(Exception e) {
                exchange.sendResponseHeaders(500, -1);
            }
        }
    }

    static class AdvogadoDetalheApiHandler implements HttpHandler {
        private Connection con;
        public AdvogadoDetalheApiHandler(Connection con) { this.con = con; }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            try {
                String query = exchange.getRequestURI().getQuery();
                int id = -1;
                if (query != null && query.contains("id=")) {
                    id = Integer.parseInt(query.split("id=")[1].split("&")[0]);
                }
                if (id == -1) { exchange.sendResponseHeaders(400, -1); return; }
                
                StringBuilder json = new StringBuilder("{");
                
                java.sql.PreparedStatement st = con.prepareStatement("SELECT p.*, a.oab, a.area_atuacao FROM Advogado a JOIN Pessoa p ON a.fk_id_pessoa = p.id_pessoa WHERE a.fk_id_pessoa = ?");
                st.setInt(1, id);
                java.sql.ResultSet rs = st.executeQuery();
                if(!rs.next()) { exchange.sendResponseHeaders(404, -1); return; }
                
                String nome = rs.getString("primeiro_nome");
                String ultimo = rs.getString("ultimo_nome");
                if(ultimo != null && !ultimo.isEmpty()) nome += " " + ultimo;
                
                json.append("\"id\":").append(rs.getInt("id_pessoa")).append(",");
                json.append("\"nome\":\"").append(nome).append("\",");
                json.append("\"oab\":\"").append(rs.getString("oab")).append("\",");
                json.append("\"area\":\"").append(rs.getString("area_atuacao")).append("\",");
                json.append("\"cpf\":\"").append(rs.getString("cpf_cnpj")).append("\",");
                rs.close(); st.close();
                
                java.sql.PreparedStatement stProc = con.prepareStatement("SELECT pr.id_processo, pr.numero_processo, pr.tipo_processo FROM Processo_Advogado pa JOIN Processo pr ON pa.fk_id_processo = pr.id_processo WHERE pa.fk_id_advogado = ?");
                stProc.setInt(1, id);
                java.sql.ResultSet rsProc = stProc.executeQuery();
                json.append("\"processos\":[");
                boolean first = true;
                while(rsProc.next()) {
                    if(!first) json.append(",");
                    json.append("{");
                    json.append("\"id\":").append(rsProc.getInt("id_processo")).append(",");
                    json.append("\"numero\":\"").append(rsProc.getString("numero_processo")).append("\",");
                    json.append("\"tipo\":\"").append(rsProc.getString("tipo_processo")).append("\"");
                    json.append("}");
                    first = false;
                }
                json.append("]");
                rsProc.close(); stProc.close();
                
                json.append("}");
                
                byte[] response = json.toString().getBytes("UTF-8");
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, response.length);
                OutputStream os = exchange.getResponseBody();
                os.write(response);
                os.close();
            } catch(Exception e) {
                e.printStackTrace();
                exchange.sendResponseHeaders(500, -1);
            }
        }
    }

    static class LeiDetalheApiHandler implements HttpHandler {
        private Connection con;
        public LeiDetalheApiHandler(Connection con) { this.con = con; }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            try {
                String query = exchange.getRequestURI().getQuery();
                int id = -1;
                if (query != null && query.contains("id=")) {
                    id = Integer.parseInt(query.split("id=")[1].split("&")[0]);
                }
                if (id == -1) { exchange.sendResponseHeaders(400, -1); return; }
                
                StringBuilder json = new StringBuilder("{");
                
                java.sql.PreparedStatement st = con.prepareStatement("SELECT * FROM Lei WHERE id_lei = ?");
                st.setInt(1, id);
                java.sql.ResultSet rs = st.executeQuery();
                if(!rs.next()) { exchange.sendResponseHeaders(404, -1); return; }
                
                json.append("\"id\":").append(rs.getInt("id_lei")).append(",");
                json.append("\"titulo\":\"").append(rs.getString("titulo")).append("\",");
                String desc = rs.getString("descricao");
                if (desc != null) desc = desc.replace("\"", "\\\"");
                json.append("\"descricao\":\"").append(desc).append("\",");
                rs.close(); st.close();
                
                java.sql.PreparedStatement stProc = con.prepareStatement("SELECT pr.id_processo, pr.numero_processo, pr.tipo_processo, pl.artigo_paragrafo_especifico FROM Processo_Lei pl JOIN Processo pr ON pl.fk_id_processo = pr.id_processo WHERE pl.fk_id_lei = ?");
                stProc.setInt(1, id);
                java.sql.ResultSet rsProc = stProc.executeQuery();
                json.append("\"processos\":[");
                boolean first = true;
                while(rsProc.next()) {
                    if(!first) json.append(",");
                    json.append("{");
                    json.append("\"id\":").append(rsProc.getInt("id_processo")).append(",");
                    json.append("\"numero\":\"").append(rsProc.getString("numero_processo")).append("\",");
                    json.append("\"tipo\":\"").append(rsProc.getString("tipo_processo")).append("\",");
                    String art = rsProc.getString("artigo_paragrafo_especifico");
                    if(art != null) art = art.replace("\"", "\\\"");
                    json.append("\"artigo\":\"").append(art).append("\"");
                    json.append("}");
                    first = false;
                }
                json.append("]");
                rsProc.close(); stProc.close();
                
                json.append("}");
                
                byte[] response = json.toString().getBytes("UTF-8");
                exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                exchange.sendResponseHeaders(200, response.length);
                OutputStream os = exchange.getResponseBody();
                os.write(response);
                os.close();
            } catch(Exception e) {
                e.printStackTrace();
                exchange.sendResponseHeaders(500, -1);
            }
        }
    }

    private static java.util.Map<String, String> parseFormData(String body) throws java.io.UnsupportedEncodingException {
        java.util.Map<String, String> map = new java.util.HashMap<>();
        String[] pairs = body.split("&");
        for (String pair : pairs) {
            String[] kv = pair.split("=");
            if (kv.length > 1) {
                String key = java.net.URLDecoder.decode(kv[0], "UTF-8");
                String value = java.net.URLDecoder.decode(kv[1], "UTF-8");
                map.put(key, value);
            }
        }
        return map;
    }

    static class CadastroApiHandler implements HttpHandler {
        private Connection con;
        public CadastroApiHandler(Connection con) { this.con = con; }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("POST".equals(exchange.getRequestMethod())) {
                try {
                    java.io.InputStream is = exchange.getRequestBody();
                    String body = new String(is.readAllBytes(), "UTF-8");
                    java.util.Map<String, String> data = parseFormData(body);
                    
                    String nome = data.get("nome");
                    String email = data.get("email");
                    String senha = data.get("senha"); // Na vida real, a senha deveria ser criptografada com hash
                    
                    java.sql.PreparedStatement st = con.prepareStatement("INSERT INTO Usuario (nome, email, senha) VALUES (?, ?, ?)");
                    st.setString(1, nome);
                    st.setString(2, email);
                    st.setString(3, senha);
                    st.executeUpdate();
                    st.close();
                    
                    String response = "Cadastro realizado com sucesso";
                    exchange.sendResponseHeaders(200, response.length());
                    OutputStream os = exchange.getResponseBody();
                    os.write(response.getBytes());
                    os.close();
                } catch(Exception e) {
                    e.printStackTrace();
                    String response = "Erro ao realizar cadastro";
                    exchange.sendResponseHeaders(500, response.length());
                    OutputStream os = exchange.getResponseBody();
                    os.write(response.getBytes());
                    os.close();
                }
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        }
    }

    static class LoginApiHandler implements HttpHandler {
        private Connection con;
        public LoginApiHandler(Connection con) { this.con = con; }
        
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("POST".equals(exchange.getRequestMethod())) {
                try {
                    java.io.InputStream is = exchange.getRequestBody();
                    String body = new String(is.readAllBytes(), "UTF-8");
                    java.util.Map<String, String> data = parseFormData(body);
                    
                    String email = data.get("email");
                    String senha = data.get("senha");
                    
                    java.sql.PreparedStatement st = con.prepareStatement("SELECT * FROM Usuario WHERE email = ? AND senha = ?");
                    st.setString(1, email);
                    st.setString(2, senha);
                    java.sql.ResultSet rs = st.executeQuery();
                    
                    if (rs.next()) {
                        String nomeUsuario = rs.getString("nome");
                        String jsonResponse = "{\"status\":\"sucesso\", \"nome\":\"" + nomeUsuario + "\"}";
                        byte[] responseBytes = jsonResponse.getBytes("UTF-8");
                        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
                        exchange.sendResponseHeaders(200, responseBytes.length);
                        OutputStream os = exchange.getResponseBody();
                        os.write(responseBytes);
                        os.close();
                    } else {
                        String response = "Credenciais invalidas";
                        exchange.sendResponseHeaders(401, response.length());
                        OutputStream os = exchange.getResponseBody();
                        os.write(response.getBytes());
                        os.close();
                    }
                    rs.close();
                    st.close();
                } catch(Exception e) {
                    e.printStackTrace();
                    String response = "Erro ao realizar login";
                    exchange.sendResponseHeaders(500, response.length());
                    OutputStream os = exchange.getResponseBody();
                    os.write(response.getBytes());
                    os.close();
                }
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        }
    }
}
