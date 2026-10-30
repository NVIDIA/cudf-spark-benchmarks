WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),
TopNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 5
)
SELECT 
    cn.c_name,
    ts.r_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.total_order_value) AS total_value,
    rs.total_avail_qty,
    rs.total_supply_cost
FROM 
    CustomerOrders co
JOIN 
    customer cn ON co.c_custkey = cn.c_custkey
JOIN 
    TopNations ts ON cn.c_nationkey = ts.r_regionkey
JOIN 
    RankedSuppliers rs ON cn.c_nationkey = rs.s_nationkey
WHERE 
    rs.rank <= 3
GROUP BY 
    cn.c_name, ts.r_name, rs.total_avail_qty, rs.total_supply_cost
ORDER BY 
    total_value DESC;