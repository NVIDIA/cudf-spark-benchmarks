
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' - ', n.n_name) AS supplier_nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' | Price: ', p.p_retailprice, ' | Available: ', ps.ps_availqty) AS part_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        CONCAT('Order #', o.o_orderkey, ' | Date: ', o.o_orderdate, ' | Total Sales: ', SUM(l.l_extendedprice * (1 - l.l_discount))) AS order_info
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    si.supplier_nation_name,
    pd.part_info,
    od.order_info
FROM 
    SupplierInfo si
JOIN 
    PartDetails pd ON si.s_suppkey = pd.p_partkey
JOIN 
    OrderDetails od ON od.o_custkey = si.s_nationkey
WHERE 
    si.s_acctbal > 1000 AND 
    pd.ps_supplycost < 50.00
ORDER BY 
    si.nation_name, od.o_orderdate DESC;
