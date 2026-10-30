
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS average_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderpriority,
    CONCAT('Customer: ', COALESCE(f.c_name, ''), ', Total Spent: ', COALESCE(f.total_spent, 0)) AS customer_info,
    CONCAT('Supplier: ', COALESCE(ss.s_name, ''), ', Parts Supplied: ', COALESCE(ss.part_count, 0), ', Total Supply Value: ', COALESCE(ss.total_supply_value, 0)) AS supplier_info,
    CONCAT('Part: ', COALESCE(pd.p_name, ''), ', Total Revenue: ', COALESCE(pd.total_revenue, 0), ', Avg Quantity: ', COALESCE(pd.average_quantity, 0)) AS product_info
FROM RankedOrders r
LEFT JOIN FrequentCustomers f ON r.o_orderkey = f.c_custkey
LEFT JOIN SupplierStats ss ON r.o_orderkey = ss.s_suppkey
LEFT JOIN ProductDetails pd ON r.o_orderkey = pd.p_partkey
WHERE r.order_rank <= 3
  AND (f.total_spent IS NOT NULL OR ss.total_supply_value IS NOT NULL)
ORDER BY r.o_orderpriority, r.o_orderdate DESC;
