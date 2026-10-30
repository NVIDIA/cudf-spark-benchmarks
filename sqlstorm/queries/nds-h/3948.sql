
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders AS o
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    cs.c_name AS Customer_Name,
    cs.total_spent AS Total_Spent,
    COALESCE(so.sub_total_orders, 0) AS Orders_Count,
    COALESCE(su.unique_parts_supplied, 0) AS Unique_Parts_Supplied,
    ROUND(su.total_supply_cost, 2) AS Total_Supply_Cost,
    r.r_name AS Region,
    RANK() OVER (ORDER BY cs.total_spent DESC) AS Total_Spent_Rank
FROM 
    CustomerSummary AS cs
JOIN 
    nation AS n ON cs.c_custkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    (SELECT 
         o.o_custkey,
         COUNT(o.o_orderkey) AS sub_total_orders
     FROM 
         orders AS o 
     WHERE 
         o.o_orderstatus = 'F' 
     GROUP BY 
         o.o_custkey) AS so ON cs.c_custkey = so.o_custkey
LEFT JOIN 
    SupplierStats AS su ON su.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp AS ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem AS l 
            JOIN orders AS o ON l.l_orderkey = o.o_orderkey 
            WHERE o.o_orderstatus = 'F'
        )
    )
WHERE 
    cs.total_spent > 1000
ORDER BY 
    Total_Spent DESC, cs.c_name;
