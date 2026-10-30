
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            ELSE CAST(p.p_size AS VARCHAR(255))
        END AS size_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND p.p_container LIKE '%BOX%'
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
        LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name
    FROM 
        partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
ExtendedInfo AS (
    SELECT 
        p.p_partkey,
        p.size_description,
        SUM(ps.ps_availqty) AS total_available,
        MIN(ps.ps_supplycost) AS min_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        FilteredParts p
        JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
        JOIN RankedSuppliers s ON ps.s_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.size_description
)
SELECT 
    c.c_name,
    e.total_available,
    e.min_supply_cost,
    e.supplier_count,
    CASE 
        WHEN e.supplier_count IS NULL THEN 'No Suppliers'
        WHEN e.supplier_count > 5 THEN 'Many Suppliers'
        ELSE 'Few Suppliers'
    END AS supplier_category
FROM 
    CustomerOrderInfo c
    LEFT JOIN ExtendedInfo e ON c.c_custkey = (SELECT MIN(c2.c_custkey) FROM customer c2 WHERE c2.c_custkey IS NOT NULL)
WHERE 
    EXISTS (
        SELECT 1 
        FROM PartSupplier ps 
        WHERE ps.ps_availqty < 100 AND ps.ps_supplycost > 50
          AND ps.ps_partkey IN (SELECT p.p_partkey FROM FilteredParts p)
    )
ORDER BY 
    c.c_name ASC, e.total_available DESC
LIMIT 10;
