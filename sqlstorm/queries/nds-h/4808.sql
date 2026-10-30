
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
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
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SD.total_available, 0) AS total_available,
    COALESCE(SD.total_cost, 0) AS total_cost,
    COALESCE(CO.total_orders, 0) AS customer_total_orders,
    CASE
        WHEN O.order_rank IS NULL THEN 'No orders'
        ELSE CAST(O.order_rank AS VARCHAR(255))
    END AS order_rank_status
FROM 
    part p
LEFT JOIN 
    SupplierDetails SD ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s))
LEFT JOIN 
    CustomerOrders CO ON CO.total_orders > 1000
LEFT JOIN 
    RankedOrders O ON O.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE 
    p.p_retailprice > 50.00
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%quality%')
ORDER BY 
    p.p_partkey, O.order_rank;
