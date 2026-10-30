
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    LEFT JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        r.rank <= 5
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rp.o_orderkey,
    rp.total_revenue,
    rp.customer_name,
    rp.nation_name,
    COALESCE(sp.total_cost, 0) AS supplier_cost
FROM 
    TopRevenueOrders rp
LEFT JOIN 
    SupplierPart sp ON rp.o_orderkey = sp.ps_partkey
WHERE 
    rp.nation_name LIKE 'N%'
ORDER BY 
    rp.total_revenue DESC
LIMIT 10;
