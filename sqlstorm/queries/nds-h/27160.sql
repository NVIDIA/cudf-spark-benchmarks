
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rnk
    FROM 
        customer c
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' at a cost of ', CAST(ps.ps_supplycost AS VARCHAR(20))) AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    rc.c_name,
    rc.c_acctbal,
    spi.supply_info,
    od.total_line_price,
    od.distinct_parts,
    od.latest_shipdate
FROM 
    RankedCustomers rc
JOIN 
    SupplierPartInfo spi ON rc.c_custkey = spi.s_suppkey
JOIN 
    OrderDetails od ON rc.c_custkey = od.o_orderkey
WHERE 
    rc.rnk <= 5
ORDER BY 
    rc.c_acctbal DESC, od.total_line_price DESC;
