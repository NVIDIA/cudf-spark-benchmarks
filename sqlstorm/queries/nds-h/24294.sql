WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate <= DATE '1996-12-31'
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        ro.o_orderdate
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
SupplierPartDetails AS (
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
NationDetails AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(c.c_acctbal) AS avg_acctbal
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    pd.p_name,
    pd.p_retailprice,
    COUNT(DISTINCT od.o_orderkey) AS order_count,
    SUM(CASE WHEN od.o_orderstatus = 'F' THEN od.o_totalprice ELSE 0 END) AS final_order_value,
    ND.n_name AS nation_name,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Quantity'
        ELSE CAST(SUM(l.l_quantity) AS varchar(20))
    END AS total_line_item_quantity,
    ROW_NUMBER() OVER (PARTITION BY ND.n_name ORDER BY COUNT(DISTINCT od.o_orderkey) DESC) AS rn_by_nation
FROM 
    part pd
LEFT JOIN 
    lineitem l ON pd.p_partkey = l.l_partkey
LEFT JOIN 
    orders od ON l.l_orderkey = od.o_orderkey
LEFT JOIN 
    customer c ON od.o_custkey = c.c_custkey
LEFT JOIN 
    CustomerDetails CD ON c.c_custkey = CD.c_custkey
JOIN 
    NationDetails ND ON c.c_nationkey = ND.Customer_Count
WHERE 
    pd.p_size > (SELECT AVG(p_size) FROM part) 
    AND (cd.order_count > 0 OR cd.total_quantity IS NOT NULL)
GROUP BY 
    pd.p_name, pd.p_retailprice, ND.n_name
HAVING 
    COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY 
    nation_name, final_order_value DESC;
