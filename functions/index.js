const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Link này sẽ nhận dữ liệu từ MacroDroid gửi về
exports.webhookBank = functions.https.onRequest(async (req, res) => {
    // Lấy nội dung tin nhắn ngân hàng
    const fullText = req.body.content || ""; 
    console.log("Tin nhắn nhận được: ", fullText);

    // 1. Dùng Regex tìm mã Acc (Ví dụ khách chuyển: "NAP 123")
    const idMatch = fullText.match(/NAP\s*(\d+)/i);
    
    // 2. Dùng Regex tìm số tiền (Ví dụ: +500.000 hoặc +500000)
    const amountMatch = fullText.match(/\+(\d+([\d,.]?\d+)*)/);

    if (idMatch && amountMatch) {
        const accId = idMatch[1]; // Đây là số 123
        const amount = parseInt(amountMatch[1].replace(/[,.]/g, "")); // Đây là 500000

        // 3. Kiểm tra trong Database Firestore
        const accRef = admin.firestore().collection("accounts").doc(accId);
        const doc = await accRef.get();

        if (doc.exists && doc.data().price === amount) {
            // 4. Nếu khớp -> Tự động đổi trạng thái để App Flutter hiện mật khẩu
            await accRef.update({ 
                status: "Đã bán",
                paymentStatus: "Auto Bank Success",
                soldAt: admin.firestore.FieldValue.serverTimestamp()
            });
            return res.status(200).send("Thành công");
        }
    }
    res.status(200).send("Không khớp dữ liệu");
});