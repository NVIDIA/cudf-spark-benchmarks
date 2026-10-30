
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerWithHighOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IS NOT NULL
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
), 
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        COALESCE(NULLIF(p.p_container, 'BOX'), 'NONE') AS container_type,
        CASE 
            WHEN p.p_size IN (1, 5, 10) THEN 'Small'
            WHEN p.p_size IN (15, 20, 25) THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice < 50.00 OR 
        (p.p_comment IS NOT NULL AND p.p_comment LIKE '%Acceptable%')
), 
FrequentCustomers AS (
    SELECT 
        cw.c_custkey,
        RANK() OVER (ORDER BY SUM(cl.l_quantity) DESC) AS customer_rank
    FROM 
        CustomerWithHighOrders cw
    JOIN 
        orders o ON cw.c_custkey = o.o_custkey
    JOIN 
        lineitem cl ON o.o_orderkey = cl.l_orderkey
    GROUP BY 
        cw.c_custkey
), 
SupplierPartCombination AS (
    SELECT 
        rp.s_suppkey,
        fp.p_partkey,
        fp.p_name,
        fp.container_type,
        fp.size_category,
        fp.ps_availqty,
        SUM(fp.ps_supplycost) AS total_supply_cost
    FROM 
        RankedSuppliers rp
    JOIN 
        partsupp ps ON rp.s_suppkey = ps.ps_suppkey
    JOIN 
        FilteredParts fp ON ps.ps_partkey = fp.p_partkey
    GROUP BY 
        rp.s_suppkey, 
        fp.p_partkey, 
        fp.p_name, 
        fp.container_type, 
        fp.size_category,
        fp.ps_availqty
)
SELECT 
    f.c_custkey,
    sp.p_partkey,
    sp.p_name,
    sp.container_type,
    sp.size_category,
    COALESCE(SUM(sp.total_supply_cost), 0) AS total_supply_cost,
    COUNT(DISTINCT sp.s_suppkey) AS supplier_count,
    MAX(sp.total_supply_cost) AS max_supply_cost
FROM 
    FrequentCustomers f
LEFT JOIN 
    SupplierPartCombination sp ON f.c_custkey = f.c_custkey
GROUP BY 
    f.c_custkey, 
    sp.p_partkey, 
    sp.p_name, 
    sp.container_type, 
    sp.size_category
HAVING 
    COUNT(DISTINCT sp.s_suppkey) >= 2
ORDER BY 
    total_supply_cost DESC, 
    supplier_count ASC
LIMIT 10;
