WITH supplier_totals AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps_suppkey) AS unique_suppliers
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size, p.p_retailprice
),
customer_analysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown Balance'
            WHEN c.c_acctbal < 1000 THEN 'Low Value Customer'
            ELSE 'High Value Customer'
        END AS customer_value,
        ROW_NUMBER() OVER (PARTITION BY 
            CASE 
                WHEN c.c_acctbal IS NULL THEN 'Unknown'
                WHEN c.c_acctbal < 1000 THEN 'Low'
                ELSE 'High'
            END ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
),
nation_avg AS (
    SELECT 
        n.n_regionkey,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
),
final_selection AS (
    SELECT 
        pt.p_partkey,
        pt.p_name,
        pt.size_category,
        st.total_supply_cost,
        ca.customer_value,
        na.avg_supplier_balance
    FROM 
        part_details pt
    JOIN 
        supplier_totals st ON pt.p_partkey = st.ps_partkey
    LEFT JOIN 
        customer_analysis ca ON ca.rank <= 5 
    LEFT JOIN 
        nation_avg na ON na.n_regionkey = 1 
    WHERE 
        st.unique_suppliers > 3 AND 
        (na.avg_supplier_balance IS NOT NULL OR pt.p_retailprice > 100)
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.size_category,
    f.total_supply_cost,
    f.customer_value,
    f.avg_supplier_balance
FROM 
    final_selection f
ORDER BY 
    f.size_category DESC, f.total_supply_cost DESC, f.customer_value;
