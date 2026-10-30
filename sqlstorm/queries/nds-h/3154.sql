
WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= '1996-01-01' AND l_shipdate < '1997-01-01'
    GROUP BY 
        l_partkey
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        r.r_name AS supplier_region,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.nation_key,
        s.supply_products
    FROM 
        (SELECT 
            s.s_suppkey, 
            s.s_name, 
            s.s_acctbal,
            n.n_nationkey AS nation_key,
            COUNT(DISTINCT ps.ps_partkey) AS supply_products
        FROM 
            supplier s
        LEFT JOIN 
            partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN 
            nation n ON s.s_nationkey = n.n_nationkey
        GROUP BY 
            s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey) s
    WHERE 
        s.supply_products > 5
), 
RevenueByPart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(RBP.total_revenue) AS total_revenue,
    COUNT(DISTINCT TS.s_suppkey) AS number_of_suppliers
FROM 
    RevenueByPart RBP
JOIN 
    partsupp PS ON RBP.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
JOIN 
    TopSuppliers TS ON TS.s_suppkey = S.s_suppkey
WHERE 
    RBP.total_revenue > 10000
GROUP BY 
    R.r_name, N.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
