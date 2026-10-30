WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS number_of_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    ns.n_name AS national_name,
    r.r_name AS region_name,
    COALESCE(ss.total_availqty, 0) AS total_available_quantity,
    COALESCE(os.total_price, 0) AS total_order_price,
    os.number_of_parts,
    CASE 
        WHEN os.total_price > 1000 THEN 'High Value'
        WHEN os.total_price BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    nation ns
LEFT JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierSummary ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON ns.n_nationkey = os.o_custkey
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    r.r_name, ns.n_name;