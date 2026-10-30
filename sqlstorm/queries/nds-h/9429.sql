
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name AS customer_name,
        c.c_mktsegment,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_mktsegment
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FinalResult AS (
    SELECT 
        sd.s_name AS supplier_name,
        sd.nation_name,
        od.customer_name,
        od.c_mktsegment,
        od.o_orderkey,
        od.o_totalprice,
        od.o_orderdate,
        ps.total_available_qty,
        ps.avg_supply_cost,
        od.line_item_count
    FROM 
        SupplierDetails sd
    JOIN 
        OrderDetails od ON sd.s_suppkey = (
            SELECT 
                ps.ps_suppkey 
            FROM 
                partsupp ps 
            WHERE 
                ps.ps_partkey IN (
                    SELECT 
                        p.p_partkey
                    FROM 
                        part p 
                    WHERE 
                        p.p_size > 20 AND 
                        p.p_retailprice BETWEEN 100 AND 500
                )
            LIMIT 1
        )
    JOIN 
        PartSupplierDetails ps ON ps.ps_partkey IN (
            SELECT 
                p.p_partkey 
            FROM 
                part p
            WHERE 
                p.p_type LIKE '%metal%'
        )
)
SELECT 
    supplier_name,
    nation_name,
    customer_name,
    c_mktsegment,
    o_orderkey,
    o_totalprice,
    o_orderdate,
    total_available_qty,
    avg_supply_cost,
    line_item_count
FROM 
    FinalResult
ORDER BY 
    o_totalprice DESC, 
    nation_name;
