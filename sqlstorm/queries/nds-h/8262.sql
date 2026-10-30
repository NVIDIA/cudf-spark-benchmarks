WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name AS supplier_name,
        s.s_acctbal AS supplier_account_balance,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderpriority,
    COUNT(DISTINCT coi.c_custkey) AS customer_count,
    AVG(spi.supplier_account_balance) AS avg_supplier_balance,
    SUM(spi.p_retailprice) AS total_retail_price
FROM RankedOrders r
JOIN CustomerOrderInfo coi ON r.o_orderkey = coi.o_orderkey
LEFT JOIN SupplierPartInfo spi ON spi.ps_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 100.00
)
WHERE r.rn <= 5
GROUP BY r.o_orderkey, r.o_orderdate, r.o_totalprice, r.o_orderpriority
ORDER BY r.o_orderdate DESC, total_retail_price DESC;