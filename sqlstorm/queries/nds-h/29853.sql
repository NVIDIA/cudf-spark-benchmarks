
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    rc.c_name AS Customer_Name,
    rc.c_acctbal AS Customer_Balance,
    hvs.s_name AS Supplier_Name,
    hvs.s_acctbal AS Supplier_Balance,
    pd.p_name AS Part_Name,
    pd.supplier_count AS Number_of_Suppliers,
    pd.total_supplycost AS Total_Supply_Cost
FROM 
    RankedCustomers rc
JOIN 
    HighValueSuppliers hvs ON rc.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = 1
        ) 
        ORDER BY c.c_acctbal DESC
        LIMIT 1
    )
JOIN 
    PartDetails pd ON pd.total_supplycost > 1000
WHERE 
    rc.rank = 1 AND hvs.rn <= 5
ORDER BY 
    rc.c_acctbal DESC, hvs.s_acctbal DESC;
