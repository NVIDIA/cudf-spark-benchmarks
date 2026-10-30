WITH RegionalSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal,
        ROW_NUMBER() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS region_rank
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
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
FilteredResults AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        COALESCE(od.net_value, 0) AS order_value,
        rs.region_name,
        rs.nation_count
    FROM 
        CustomerOrders cs
    JOIN 
        RegionalSummary rs ON cs.c_custkey % 10 = rs.region_rank  
    LEFT JOIN 
        OrderDetails od ON cs.c_custkey = od.o_orderkey
    WHERE 
        cs.order_count > 10 
        AND (cs.total_spent IS NOT NULL OR rs.total_acctbal > 1000)
        AND od.net_value IS NOT NULL
)
SELECT 
    r.region_name,
    COUNT(fr.c_custkey) AS customer_count,
    AVG(fr.total_spent) AS avg_spent,
    MAX(fr.order_value) AS max_order_value
FROM 
    FilteredResults fr
RIGHT JOIN 
    RegionalSummary r ON fr.nation_count = r.nation_count
GROUP BY 
    r.region_name
HAVING 
    COUNT(fr.c_custkey) > 5
ORDER BY 
    avg_spent DESC;