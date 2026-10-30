WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-10-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_lines
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-10-01'
    GROUP BY 
        l.l_orderkey
),
CustomerCountry AS (
    SELECT 
        c.c_custkey,
        n.n_name AS country,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name
)
SELECT 
    COALESCE(c.country, 'Unknown Country') AS country,
    SUM(coalesce(l.total_revenue, 0)) AS total_revenue,
    AVG(sd.avg_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    CustomerCountry c
LEFT JOIN 
    LineItemStats l ON c.c_custkey = l.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.total_available_quantity > 1000
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = l.l_orderkey
WHERE 
    c.total_spent > 1000
GROUP BY 
    c.country
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;