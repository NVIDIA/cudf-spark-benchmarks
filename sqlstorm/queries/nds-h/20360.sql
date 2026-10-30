
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
),
SupplierInformation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Low'
            WHEN p.p_retailprice < 20 THEN 'Low'
            WHEN p.p_retailprice BETWEEN 20 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000 OR COUNT(o.o_orderkey) IS NULL
)
SELECT 
    r.o_orderkey,
    c.c_name,
    p.p_name,
    s.s_name,
    s.total_supply_cost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    SUM(l.l_tax) AS total_tax,
    MAX(l.l_shipdate) AS latest_ship_date
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    CustomerSummary c ON r.o_custkey = c.c_custkey
JOIN 
    HighValueParts p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierInformation s ON l.l_suppkey = s.s_suppkey
WHERE 
    p.price_category = 'High' AND 
    (s.total_supply_cost IS NULL OR s.total_supply_cost > 1000) AND 
    r.rnk <= 10
GROUP BY 
    r.o_orderkey, c.c_name, p.p_name, s.s_name, s.total_supply_cost
ORDER BY 
    revenue DESC, total_tax ASC;
