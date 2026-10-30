
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'P') AND 
        l.l_shipdate < o.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    np.n_name AS nation_name,
    rs.s_name AS supplier_name,
    hp.p_name AS high_value_part,
    od.o_orderdate,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue,
    COUNT(DISTINCT od.o_orderkey) AS order_count
FROM 
    RankedSuppliers rs
JOIN 
    nation np ON rs.s_suppkey = np.n_nationkey
JOIN 
    region r ON np.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueParts hp ON np.n_nationkey = hp.p_partkey
INNER JOIN 
    OrderDetails od ON hp.p_partkey = od.l_partkey
WHERE 
    rs.rnk = 1 AND
    od.l_returnflag = 'N'
GROUP BY 
    r.r_name, np.n_name, rs.s_name, hp.p_name, od.o_orderdate
HAVING 
    SUM(od.l_extendedprice * (1 - od.l_discount)) > 0
ORDER BY 
    total_revenue DESC;
