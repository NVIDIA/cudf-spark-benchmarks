WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        S.s_name AS supplier_name, 
        C.c_name AS customer_name, 
        O.o_orderdate, 
        L.l_quantity, 
        L.l_extendedprice, 
        L.l_discount,
        L.l_tax
    FROM 
        part p 
    JOIN 
        partsupp PS ON p.p_partkey = PS.ps_partkey 
    JOIN 
        supplier S ON PS.ps_suppkey = S.s_suppkey 
    JOIN 
        lineitem L ON p.p_partkey = L.l_partkey 
    JOIN 
        orders O ON L.l_orderkey = O.o_orderkey 
    JOIN 
        customer C ON O.o_custkey = C.c_custkey 
),
AggregatedData AS (
    SELECT 
        p_name,
        COUNT(DISTINCT supplier_name) AS total_suppliers,
        SUM(l_quantity) AS total_quantity,
        SUM(l_extendedprice) AS total_extended_price,
        SUM(l_discount) AS total_discounted_price,
        SUM(l_tax) AS total_tax
    FROM 
        PartDetails 
    GROUP BY 
        p_name
)
SELECT 
    p_name,
    total_suppliers,
    total_quantity,
    total_extended_price,
    total_discounted_price,
    total_tax,
    CASE 
        WHEN total_quantity > 100 THEN 'High Volume'
        WHEN total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    AggregatedData
WHERE 
    total_extended_price > 1000
ORDER BY 
    total_extended_price DESC;
