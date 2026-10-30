WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n 
    ON 
        s.s_nationkey = n.n_nationkey
), HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), PopularCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o 
    ON 
        c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) >= 5
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    rs.s_name AS supplier,
    hp.total_value AS high_value_part,
    pc.c_name AS popular_customer,
    pc.order_count
FROM 
    RankedSuppliers rs
JOIN 
    nation ns 
ON 
    rs.s_suppkey = ns.n_nationkey
JOIN 
    region r 
ON 
    ns.n_regionkey = r.r_regionkey
JOIN 
    HighValueParts hp 
ON 
    rs.s_suppkey = hp.ps_partkey
JOIN 
    PopularCustomers pc 
ON 
    pc.c_custkey = rs.s_suppkey
WHERE 
    rs.rank <= 3
ORDER BY 
    r.r_name, ns.n_name, hp.total_value DESC;
