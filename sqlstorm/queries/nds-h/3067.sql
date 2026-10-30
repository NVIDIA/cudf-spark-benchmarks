WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SI.s_name AS supplier_name,
    CO.c_name AS customer_name,
    CO.total_orders,
    CO.total_spent,
    CASE 
        WHEN CO.total_spent IS NULL THEN 'No Orders'
        WHEN CO.total_spent > 1000 THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS customer_type,
    R.order_rank,
    COALESCE(SI.total_supplycost, 0) AS total_supplycost
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplierinfo SI ON ps.ps_suppkey = SI.s_suppkey
LEFT JOIN 
    customerorders CO ON CO.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'O' GROUP BY o2.o_custkey) LIMIT 1)
LEFT JOIN 
    RankedOrders R ON R.o_orderkey = (SELECT o_orderkey FROM orders ORDER BY o_orderdate DESC LIMIT 1)
WHERE 
    p.p_retailprice IS NOT NULL AND 
    (p.p_size < 100 AND (p.p_brand LIKE 'Brand%' OR p.p_name LIKE '%A%'))
ORDER BY 
    p.p_partkey,
    total_spent DESC;