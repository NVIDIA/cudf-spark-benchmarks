WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUBSTRING(s.s_address, 1, 20) AS short_address,
        s.s_comment,
        CONCAT('Supplier: ', s.s_name, ', Address: ', SUBSTRING(s.s_address, 1, 20), ', Comment: ', s.s_comment) AS supplier_info
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_info
    FROM 
        part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalBenchmark AS (
    SELECT 
        sd.supplier_info,
        pd.part_info,
        co.c_name,
        co.order_count,
        co.total_spent
    FROM 
        SupplierDetails sd
    JOIN 
        partsupp ps ON ps.ps_suppkey = sd.s_suppkey
    JOIN 
        PartDetails pd ON pd.p_partkey = ps.ps_partkey
    JOIN 
        CustomerOrders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2))
    WHERE 
        sd.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
)
SELECT 
    CONCAT(supplier_info, ' | ', part_info, ' | Customer: ', c_name, ', Orders: ', order_count, ', Total Spent: ', total_spent) AS benchmark_output
FROM 
    FinalBenchmark
ORDER BY 
    total_spent DESC
LIMIT 10;
