WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplyChain AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        COALESCE(RankedSupplier.s_name, 'Unknown Supplier') AS supplier_name,
        COALESCE(HighValueCustomers.total_spent, 0) AS high_value_customer_spent
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        RankedSupplier ON ps.ps_suppkey = RankedSupplier.s_suppkey AND RankedSupplier.rnk = 1
    LEFT JOIN 
        HighValueCustomers ON ps.ps_partkey = HighValueCustomers.c_custkey
)
SELECT 
    sc.p_partkey, 
    sc.p_name, 
    sc.supplier_name,
    CASE 
        WHEN sc.high_value_customer_spent > 5000 AND sc.ps_availqty < 100 THEN 'High Risk Item'
        ELSE 'Standard Item'
    END AS item_category,
    ROW_NUMBER() OVER (ORDER BY sc.high_value_customer_spent DESC, sc.p_partkey) AS item_rank
FROM 
    SupplyChain sc
WHERE 
    sc.ps_supplycost IS NOT NULL
ORDER BY 
    item_category, item_rank;
