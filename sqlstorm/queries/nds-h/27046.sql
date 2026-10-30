WITH CategorizedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large' 
        END AS Size_Category
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        n.n_name AS Nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
SalesData AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
),
FinalReport AS (
    SELECT 
        cp.p_partkey, 
        cp.p_name, 
        cp.Size_Category, 
        sd.s_name AS Supplier_Name, 
        sd.Nation, 
        sd.s_acctbal, 
        COALESCE(sd.s_acctbal, 0) AS Adjusted_Account_Balance,
        sd.s_name || ' supplies ' || cp.p_name AS Supplier_Info,
        SUM(sd.s_acctbal) OVER (PARTITION BY cp.Size_Category) AS Total_Balance_By_Category,
        sd.s_name || ' - ' || cp.p_brand AS Detailed_Info,
        CASE 
            WHEN sd.s_acctbal IS NULL THEN 'Supplier Not Found'
            ELSE 'Supplier Found'
        END AS Supplier_Status
    FROM CategorizedParts cp
    LEFT JOIN SupplierDetails sd ON cp.p_partkey = sd.s_suppkey
)
SELECT 
    p_partkey, 
    p_name, 
    Size_Category, 
    Supplier_Name, 
    Nation,
    Adjusted_Account_Balance,
    Supplier_Info,
    Total_Balance_By_Category,
    Detailed_Info,
    Supplier_Status
FROM FinalReport
ORDER BY Size_Category, Adjusted_Account_Balance DESC;
