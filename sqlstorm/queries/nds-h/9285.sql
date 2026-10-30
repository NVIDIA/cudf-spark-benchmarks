WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey AS customer_id,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        c.c_custkey
),
TopProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        revenue DESC
    LIMIT 10
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.total_account_balance,
    co.customer_id,
    co.order_count,
    co.total_spent,
    tp.p_name,
    tp.revenue
FROM 
    RegionStats rs
LEFT JOIN 
    CustomerOrders co ON 1 = 1  
CROSS JOIN 
    TopProducts tp
ORDER BY 
    rs.region_name, co.total_spent DESC, tp.revenue DESC;