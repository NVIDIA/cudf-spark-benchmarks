
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
), SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), LatestLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_receiptdate DESC) AS rk
    FROM 
        lineitem l
    WHERE 
        l.l_discount < 0.05
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    COALESCE(AVG(l.l_extendedprice * (1 - l.l_discount)), 0) AS avg_discounted_price,
    SUM(CASE 
        WHEN o.o_orderstatus = 'F' THEN l.l_quantity 
        ELSE 0 
    END) AS fulfilled_quantity,
    SUM(CASE 
        WHEN o.o_orderstatus = 'O' AND lo.rn = 1 THEN 1 
        ELSE 0 
    END) AS recent_open_orders
FROM 
    part p
LEFT JOIN 
    LatestLineItems l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierCosts s_cost ON p.p_partkey = s_cost.ps_partkey
LEFT JOIN 
    supplier s ON s_cost.ps_suppkey = s.s_suppkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    (
        SELECT 
            l_orderkey, 
            COUNT(*) AS qty,
            ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY COUNT(*) DESC) AS rn
        FROM 
            lineitem
        GROUP BY 
            l_orderkey
    ) lo ON l.l_orderkey = lo.l_orderkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
HAVING 
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE 0 
    END) > 100
ORDER BY 
    avg_discounted_price DESC;
