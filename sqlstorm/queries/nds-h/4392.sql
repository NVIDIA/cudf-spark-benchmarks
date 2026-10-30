WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        PERCENT_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS price_rank
    FROM 
        partsupp ps
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_address,
        COALESCE(RD.total_orders, 0) AS total_orders
    FROM 
        supplier s
    LEFT JOIN (
        SELECT 
            l.l_suppkey,
            COUNT(DISTINCT o.o_orderkey) AS total_orders
        FROM 
            lineitem l
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_orderstatus = 'O'
        GROUP BY 
            l.l_suppkey
    ) RD ON s.s_suppkey = RD.l_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_acctbal IS NOT NULL
        )
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS num_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    MAX(o.o_totalprice) AS max_order_price
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    SupplyDetails sd ON l.l_partkey = sd.ps_partkey
JOIN 
    TopSuppliers s ON l.l_suppkey = s.s_suppkey
WHERE 
    o.o_orderstatus = 'O'
    AND sd.price_rank <= 0.1
    AND (p.p_retailprice > 100.00 OR p.p_size < 10)
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    total_revenue DESC;