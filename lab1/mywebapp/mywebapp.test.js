const request = require('supertest');
const app = require('./mywebapp');
const pool = require('./db');

jest.mock('./db', () => ({
  query: jest.fn()
}));

describe('Simple Inventory API Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Health Endpoints', () => {
    it('GET /health/alive повинен повертати 200 OK', async () => {
      const res = await request(app).get('/health/alive');
      expect(res.statusCode).toEqual(200);
      expect(res.text).toBe('OK');
    });

    it('GET /health/ready повинен повертати 200 OK при доступній БД', async () => {
      pool.query.mockResolvedValueOnce([[{ 1: 1 }]]);
      const res = await request(app).get('/health/ready');
      expect(res.statusCode).toEqual(200);
      expect(res.text).toBe('OK');
    });

    it('GET /health/ready повинен повертати 500 при помилці БД', async () => {
      pool.query.mockRejectedValueOnce(new Error('DB Error'));
      const res = await request(app).get('/health/ready');
      expect(res.statusCode).toEqual(500);
    });
  });

  describe('Main & Items Endpoints', () => {
    it('GET / повинен повертати HTML', async () => {
      const res = await request(app).get('/').set('Accept', 'text/html');
      expect(res.statusCode).toEqual(200);
      expect(res.text).toContain('Simple Inventory API');
    });

    it('GET /items повинен повертати список у форматі JSON', async () => {
      const mockItems = [{ id: 1, name: 'Стілець' }, { id: 2, name: 'Стіл' }];
      pool.query.mockResolvedValueOnce([mockItems]);

      const res = await request(app).get('/items').set('Accept', 'application/json');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toEqual(mockItems);
    });

    it('POST /items повинен успішно створювати новий предмет', async () => {
      pool.query.mockResolvedValueOnce([{ insertId: 3 }]);

      const res = await request(app)
        .post('/items')
        .send({ name: 'Шафа', quantity: 5 })
        .set('Accept', 'application/json');

      expect(res.statusCode).toEqual(201);
      expect(res.body).toEqual({ id: 3, name: 'Шафа', quantity: 5 });
    });

    it('GET /items/:id повинен повертати конкретний предмет', async () => {
      const mockItem = { id: 1, name: 'Стілець', quantity: 10, created_at: '2023-01-01' };
      pool.query.mockResolvedValueOnce([[mockItem]]);

      const res = await request(app).get('/items/1').set('Accept', 'application/json');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toEqual(mockItem);
    });
  });
});