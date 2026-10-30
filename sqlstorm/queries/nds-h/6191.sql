WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PopularParts AS (
    SELECT 
        l.l_partkey,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
    HAVING 
        COUNT(l.l_orderkey) > 100
)
SELECT 
    p.p_name,
    p.p_size,
    p.p_mfgr,
    AVG(rc.total_cost) AS avg_supplier_cost,
    SUM(ro.o_totalprice) AS total_sales
FROM 
    part p
JOIN 
    SupplierCost rc ON p.p_partkey = rc.ps_partkey
JOIN 
    PopularParts pp ON pp.l_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
WHERE 
    ro.price_rank <= 5
GROUP BY 
    p.p_name, p.p_size, p.p_mfgr
ORDER BY 
    total_sales DESC;