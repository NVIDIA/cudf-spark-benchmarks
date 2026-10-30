
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT 
        rc.c_custkey,
        rc.c_name,
        rc.total_spent
    FROM 
        RankedCustomers rc
    WHERE 
        rc.spending_rank <= 10
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
)
SELECT 
    hp.c_name AS High_Spender_Name,
    spd.s_name AS Supplier_Name,
    spd.supplier_count,
    spd.avg_supplycost,
    CASE 
        WHEN spd.avg_supplycost IS NULL THEN 'No Supplies Available'
        ELSE CAST(spd.avg_supplycost AS STRING)
    END AS Avg_Supply_Cost_String,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE 
        WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
        ELSE l.l_extendedprice 
    END) AS total_sales
FROM 
    HighSpenders hp
JOIN 
    orders o ON hp.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SupplierPartDetails spd ON l.l_partkey = spd.ps_partkey
GROUP BY 
    hp.c_name, spd.s_name, spd.supplier_count, spd.avg_supplycost
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0
ORDER BY 
    hp.c_name, spd.s_name;
