
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000
),
FrequentOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(s.s_name, 'Not Available') AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    PS.p_partkey,
    PS.p_name,
    PS.supplier_name,
    PS.ps_supplycost,
    PS.ps_availqty,
    HS.total_available,
    HS.total_supplycost,
    COALESCE(FC.order_count, 0) AS frequent_order_count
FROM 
    PartSupplierDetails PS
LEFT JOIN 
    SupplierStats HS ON PS.supplier_name = HS.s_name
LEFT JOIN 
    FrequentOrders FC ON FC.o_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MAX(o1.o_orderkey) FROM orders o1) LIMIT 1)
WHERE 
    PS.ps_availqty > 10
ORDER BY 
    PS.ps_availqty DESC, 
    HS.total_supplycost ASC;
