
WITH SupplierAverage AS (
    SELECT 
        s_nationkey,
        AVG(s_acctbal) AS avg_acctbal
    FROM 
        supplier
    GROUP BY 
        s_nationkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(od.total_revenue) AS nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
), 
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sa.avg_acctbal,
        COALESCE(nr.nation_revenue, 0) AS total_revenue
    FROM 
        supplier s
    JOIN 
        SupplierAverage sa ON s.s_nationkey = sa.s_nationkey
    LEFT JOIN 
        NationRevenue nr ON s.s_nationkey = nr.n_nationkey
)

SELECT 
    sn.s_suppkey,
    sn.s_name,
    sn.avg_acctbal,
    sn.total_revenue,
    CASE 
        WHEN sn.avg_acctbal > 10000 THEN 'High Value'
        WHEN sn.avg_acctbal IS NULL THEN 'Unknown'
        ELSE 'Low Value' 
    END AS supplier_value_category
FROM 
    SupplierNation sn
WHERE 
    sn.total_revenue > (SELECT AVG(nation_revenue) FROM NationRevenue)
ORDER BY 
    sn.total_revenue DESC;
