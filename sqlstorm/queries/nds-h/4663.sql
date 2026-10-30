
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(sd.total_supply_cost), 0) AS total_supplier_cost,
    ROW_NUMBER() OVER (PARTITION BY r.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation r ON c.c_nationkey = r.n_nationkey
LEFT JOIN 
    SupplierPartDetails sd ON sd.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    r.n_nationkey, r.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (
        SELECT AVG(total_revenue) 
        FROM (
            SELECT 
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
            FROM 
                lineitem l
            JOIN 
                orders o ON l.l_orderkey = o.o_orderkey
            GROUP BY 
                o.o_orderdate
        ) AS subquery
    )
ORDER BY 
    revenue_rank, total_orders DESC;
