
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
NationAggregates AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS num_customers,
        SUM(o.o_totalprice) AS total_orders_value
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
),
TopPartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    c.customer_name,
    c.total_spent,
    na.num_customers,
    na.total_orders_value,
    COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
FROM part p
JOIN TopPartSuppliers ps ON p.p_partkey = ps.ps_partkey
JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN CustomerPurchases c ON c.c_custkey = n.n_nationkey
JOIN NationAggregates na ON na.n_name = n.n_name
WHERE s.rn <= 3
GROUP BY 
    p.p_name, p.p_brand, p.p_type, s.s_name, r.r_name, c.customer_name, 
    c.total_spent, na.num_customers, na.total_orders_value
ORDER BY p.p_name, num_suppliers DESC;
