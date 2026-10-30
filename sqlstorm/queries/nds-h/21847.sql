WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    c.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_revenue,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE NULL 
    END) AS avg_returned_quantity,
    CASE 
        WHEN COUNT(DISTINCT l.l_orderkey) > 0 THEN 'Regular Customer' 
        ELSE 'New Customer' 
    END AS customer_status,
    rp.p_name,
    rp.p_brand
FROM 
    CustomerOrders co
JOIN customer c ON co.c_custkey = c.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN RankedParts rp ON l.l_partkey = rp.p_partkey AND rp.rn <= 5
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
GROUP BY 
    c.c_name, rp.p_name, rp.p_brand
HAVING 
    SUM(l.l_extendedprice) > 10000 OR COUNT(*) > 10
ORDER BY 
    net_revenue DESC 
LIMIT 10;
